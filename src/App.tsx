import { useState, useEffect, useMemo } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { 
  QrCode, 
  Copy, 
  Check, 
  User, 
  MapPin, 
  Key, 
  CircleDollarSign, 
  FileText, 
  Hash,
  Smartphone,
  Info,
  History,
  Trash2,
  RefreshCw,
  Calendar,
  Save
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { generatePixPayload, type PixData } from './lib/pix-utils';
import { cn } from './lib/utils';

interface PixHistoryItem extends PixData {
  id: string;
  timestamp: number;
  payload: string;
}

export default function App() {
  const [formData, setFormData] = useState<PixData>({
    key: '',
    receiverName: '',
    receiverCity: '',
    amount: '',
    description: '',
    txid: '',
  });

  const [history, setHistory] = useState<PixHistoryItem[]>([]);
  const [copied, setCopied] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Load history from localStorage
  useEffect(() => {
    const savedHistory = localStorage.getItem('pix_history');
    if (savedHistory) {
      try {
        setHistory(JSON.parse(savedHistory));
      } catch (e) {
        console.error('Failed to parse history', e);
      }
    }
  }, []);

  // Save history to localStorage
  useEffect(() => {
    localStorage.setItem('pix_history', JSON.stringify(history));
  }, [history]);

  const pixPayload = useMemo(() => {
    if (!formData.key || !formData.receiverName || !formData.receiverCity) return '';
    try {
      return generatePixPayload(formData);
    } catch (e) {
      console.error(e);
      return '';
    }
  }, [formData]);

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const saveToHistory = () => {
    if (!pixPayload) return;
    
    const newItem: PixHistoryItem = {
      ...formData,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      payload: pixPayload
    };

    setHistory(prev => [newItem, ...prev].slice(0, 50)); // Keep last 50
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 2000);
  };

  const deleteFromHistory = (id: string) => {
    setHistory(prev => prev.filter(item => item.id !== id));
  };

  const loadFromHistory = (item: PixHistoryItem) => {
    setFormData({
      key: item.key,
      receiverName: item.receiverName,
      receiverCity: item.receiverCity,
      amount: item.amount || '',
      description: item.description || '',
      txid: item.txid || '',
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const isFormValid = formData.key && formData.receiverName && formData.receiverCity;

  return (
    <div className="min-h-screen flex flex-col items-center p-4 md:p-8 max-w-5xl mx-auto">
      <header className="w-full text-center mb-8">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="inline-flex items-center justify-center p-3 rounded-2xl pix-gradient text-white mb-4 shadow-lg"
        >
          <QrCode size={32} />
        </motion.div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Gerador de PIX</h1>
        <p className="text-slate-500 mt-2">Crie QR Codes estáticos para receber pagamentos instantâneos</p>
      </header>

      <main className="w-full grid grid-cols-1 lg:grid-cols-2 gap-8 items-start mb-12">
        {/* Form Section */}
        <section className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold flex items-center gap-2 text-slate-800">
              <Info size={18} className="text-pix" />
              Dados do Recebedor
            </h2>
            
            <div className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  <Key size={14} /> Chave PIX *
                </label>
                <input
                  type="text"
                  placeholder="CPF, CNPJ, E-mail, Telefone ou Aleatória"
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.key}
                  onChange={(e) => setFormData({ ...formData, key: e.target.value })}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  <User size={14} /> Nome do Recebedor *
                </label>
                <input
                  type="text"
                  placeholder="Ex: João Silva"
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.receiverName}
                  onChange={(e) => setFormData({ ...formData, receiverName: e.target.value })}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  <MapPin size={14} /> Cidade *
                </label>
                <input
                  type="text"
                  placeholder="Ex: São Paulo"
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.receiverCity}
                  onChange={(e) => setFormData({ ...formData, receiverCity: e.target.value })}
                />
              </div>
            </div>
          </div>

          <div className="space-y-4 pt-4 border-t border-slate-100">
            <h2 className="text-lg font-semibold flex items-center gap-2 text-slate-800">
              <CircleDollarSign size={18} className="text-pix" />
              Detalhes do Pagamento (Opcional)
            </h2>

            <div className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  Valor (R$)
                </label>
                <input
                  type="number"
                  step="0.01"
                  placeholder="0,00"
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.amount}
                  onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  <FileText size={14} /> Descrição (infoAdicional)
                </label>
                <input
                  type="text"
                  placeholder="Ex: Pagamento do Almoço"
                  maxLength={50}
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-slate-700 flex items-center gap-2">
                  <Hash size={14} /> ID da Transação (txid)
                </label>
                <input
                  type="text"
                  placeholder="Ex: PEDIDO123"
                  maxLength={25}
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-pix focus:border-transparent outline-none transition-all"
                  value={formData.txid}
                  onChange={(e) => setFormData({ ...formData, txid: e.target.value })}
                />
              </div>
            </div>
          </div>
        </section>

        {/* Preview Section */}
        <section className="sticky top-8 space-y-6">
          <div className="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 flex flex-col items-center text-center">
            <AnimatePresence mode="wait">
              {isFormValid ? (
                <motion.div
                  key="qr-active"
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  className="w-full flex flex-col items-center"
                >
                  <div className="bg-slate-50 p-6 rounded-2xl mb-6 border border-slate-100">
                    <QRCodeSVG 
                      value={pixPayload} 
                      size={200}
                      level="M"
                      includeMargin={false}
                      className="rounded-lg"
                    />
                  </div>
                  
                  <div className="w-full space-y-4">
                    <div className="text-left bg-slate-50 p-4 rounded-xl border border-slate-100 relative group overflow-hidden">
                      <p className="text-[10px] font-mono text-slate-400 uppercase tracking-wider mb-1">Código Copia e Cola</p>
                      <p className="text-xs font-mono text-slate-600 break-all line-clamp-3">{pixPayload}</p>
                      <button 
                        onClick={() => handleCopy(pixPayload)}
                        className="absolute right-2 top-2 p-2 bg-white rounded-lg shadow-sm border border-slate-100 hover:bg-slate-50 transition-colors"
                      >
                        {copied ? <Check size={16} className="text-green-500" /> : <Copy size={16} className="text-slate-400" />}
                      </button>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <button
                        onClick={() => handleCopy(pixPayload)}
                        className="py-4 rounded-2xl pix-gradient text-white font-semibold flex items-center justify-center gap-2 shadow-lg shadow-pix/20 hover:opacity-90 active:scale-[0.98] transition-all"
                      >
                        {copied ? <Check size={20} /> : <Copy size={20} />}
                        {copied ? 'Copiado!' : 'Copiar'}
                      </button>
                      <button
                        onClick={saveToHistory}
                        className="py-4 rounded-2xl bg-slate-900 text-white font-semibold flex items-center justify-center gap-2 shadow-lg hover:bg-slate-800 active:scale-[0.98] transition-all"
                      >
                        {saveSuccess ? <Check size={20} /> : <Save size={20} />}
                        {saveSuccess ? 'Salvo!' : 'Salvar'}
                      </button>
                    </div>
                  </div>
                </motion.div>
              ) : (
                <motion.div
                  key="qr-inactive"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="py-12 flex flex-col items-center text-slate-400"
                >
                  <div className="w-48 h-48 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200 flex items-center justify-center mb-6">
                    <QrCode size={48} className="opacity-20" />
                  </div>
                  <p className="text-sm max-w-[200px]">Preencha os campos obrigatórios para gerar o QR Code</p>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          <div className="bg-pix/5 p-6 rounded-3xl border border-pix/10">
            <h3 className="text-sm font-semibold text-pix flex items-center gap-2 mb-2">
              <Smartphone size={16} />
              Dica Mobile
            </h3>
            <p className="text-xs text-slate-600 leading-relaxed">
              Você pode tirar um print desta tela ou copiar o código "Copia e Cola" para enviar pelo WhatsApp. O recebedor poderá pagar usando qualquer aplicativo de banco.
            </p>
          </div>
        </section>
      </main>

      {/* History Section */}
      <section className="w-full max-w-5xl space-y-6">
        <div className="flex items-center justify-between px-2">
          <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
            <History size={22} className="text-pix" />
            Histórico de Gerados
          </h2>
          <span className="text-xs font-medium text-slate-400 bg-slate-100 px-2 py-1 rounded-full">
            {history.length} itens
          </span>
        </div>

        {history.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <AnimatePresence initial={false}>
              {history.map((item) => (
                <motion.div
                  key={item.id}
                  layout
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-shadow group"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="space-y-1">
                      <h3 className="font-bold text-slate-800 line-clamp-1">{item.receiverName}</h3>
                      <div className="flex items-center gap-3 text-xs text-slate-400">
                        <span className="flex items-center gap-1">
                          <Calendar size={12} />
                          {new Date(item.timestamp).toLocaleDateString('pt-BR')}
                        </span>
                        <span className="flex items-center gap-1">
                          <MapPin size={12} />
                          {item.receiverCity}
                        </span>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold text-pix">
                        {item.amount ? `R$ ${parseFloat(item.amount).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}` : 'Valor Aberto'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-4 border-t border-slate-50">
                    <button
                      onClick={() => handleCopy(item.payload)}
                      className="flex-1 py-2 px-3 rounded-xl bg-slate-50 text-slate-600 text-xs font-semibold flex items-center justify-center gap-1.5 hover:bg-pix/10 hover:text-pix transition-colors"
                    >
                      <Copy size={14} />
                      Copiar
                    </button>
                    <button
                      onClick={() => loadFromHistory(item)}
                      className="flex-1 py-2 px-3 rounded-xl bg-slate-50 text-slate-600 text-xs font-semibold flex items-center justify-center gap-1.5 hover:bg-slate-900 hover:text-white transition-colors"
                    >
                      <RefreshCw size={14} />
                      Editar
                    </button>
                    <button
                      onClick={() => deleteFromHistory(item.id)}
                      className="p-2 rounded-xl bg-slate-50 text-slate-400 hover:bg-red-50 hover:text-red-500 transition-colors"
                      title="Excluir"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        ) : (
          <div className="bg-white py-12 rounded-3xl border border-slate-100 border-dashed flex flex-col items-center text-slate-400">
            <History size={40} className="opacity-10 mb-3" />
            <p className="text-sm">Nenhum PIX salvo no histórico ainda.</p>
          </div>
        )}
      </section>

      <footer className="mt-12 pb-8 text-center text-slate-400 text-xs">
        <p>© {new Date().getFullYear()} Gerador de PIX Estático</p>
        <p className="mt-1">Seguindo os padrões técnicos do Banco Central do Brasil</p>
      </footer>
    </div>
  );
}


